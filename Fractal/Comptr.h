#pragma once

template<class T>
class Comptr
{
public:
	Comptr() : t(nullptr)
	{
	}

	Comptr(T *p_t) : t(p_t)
	{
	}

	Comptr(Comptr &other) : t(other.t)
	{
		if (t)
		{
			t->AddRef();
		}
	}

	Comptr(Comptr &&other)
	{
		t = other.t;
		other.t = nullptr;
	}

	~Comptr()
	{
		if (t)
		{
			t->Release();
		}
	}

	Comptr operator = (Comptr &other)
	{
		if (t)
		{
			t->Release();
		}
		t = other.t;
		if (t)
		{
			t->AddRef();
		}
	}

	T **operator & ()
	{
		return &t;
	}

	T *operator -> ()
	{
		return t;
	}

	operator T *()
	{
		return t;
	}

	void Exchange(Comptr &other)
	{
		T *temp = t;
		t = other.t;
		other.t = temp;
	}
private:
	T *t;
};